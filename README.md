# PDF Renamer

A small macOS app that renames PDFs to the title in their header and moves them into a folder of your choice.

Click the app, pick a **source** folder, pick a **destination** folder. Every PDF in the source folder is renamed to its title (the name in the PDF's header) and moved to the destination.

For example, a file called `fdo_results_export13.pdf` whose header reads "Castellini Foundation" becomes `Castellini Foundation.pdf`.

## Install

Requires macOS and the Xcode Command Line Tools (to compile the Swift code). If you don't have them, run `xcode-select --install`.

```sh
git clone https://github.com/lucas-hennessey/pdf-renamer.git
cd pdf-renamer
./build.sh
```

This builds `~/Applications/Rename PDFs.app`. Drag it to your Dock.

The app is not signed with an Apple developer certificate. If macOS blocks the first launch, right-click the app, choose **Open**, then confirm.

## Use

1. Click **Rename PDFs** in the Dock.
2. Choose the folder that holds the PDFs to rename.
3. Choose the folder to move the renamed PDFs into (it must be different from the first).
4. A summary appears when it finishes, with an **Open Destination** button.

## Behavior

- The name is the PDF's built-in title. If it has none, it is the largest text in the top 40% of page 1. If a title wraps onto several lines of the same size, they are joined.
- A file whose top text has no letters or digits is left in place and listed as skipped.
- Duplicate names get a suffix: `Name.pdf`, `Name (2).pdf`, `Name (3).pdf`. Nothing is overwritten.
- Characters macOS doesn't allow in filenames (`/ : \ * ? " < > |`) are replaced with `-`. Names are capped at 150 characters.
- Files are moved, not copied.
- PDFs with no readable text (such as scans) are left in place and listed as skipped.
- Only PDFs directly inside the source folder are processed, not subfolders.

## Command line

The app wraps a standalone tool you can also run directly:

```sh
swiftc -O rename_pdfs.swift -o rename_pdfs
./rename_pdfs /path/to/source /path/to/destination
```

## Files

- `rename_pdfs.swift`: finds the header text with PDFKit, renames and moves the files.
- `rename_pdfs.applescript`: the folder pickers and summary dialog.
- `build.sh`: compiles the tool and packages the app.
