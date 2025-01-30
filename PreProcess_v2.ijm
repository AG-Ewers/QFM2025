//--------------------------------------------------------------------//
// -------- Batch Image Preprocessing: Smoothing & Patching --------- //
//--------------------------------------------------------------------//

/* Description: This macro processes all images in a folder, and:
    1) applies optional Gaussian smoothing,
    2) splits them into patches,
    3) and saves the processed images in TIFF, JPEG, or PNG format.

 User Inputs:
 - Input folder: The folder containing images to be processed.
 - Output folder: The folder where processed images will be saved.
 - Number of patches OR patch size: Determines how images are split.
 - Gaussian smoothing sigma: 0 means no filtering, otherwise applies smoothing.
 - Output format: TIFF, JPEG, or PNG.

 Author: Amin Zehtabian  (amin.zehtabian@fu-berlin.de)
 Last Update: Jan2025
*/

// Ask for paths:
inputDir = getDirectory("Choose the input folder : ");
outputDir = getDirectory("Choose the output folder : ");

if (inputDir == "" || outputDir == "") {
    exit("Input or output folder not specified.");
}

// Patching parameters:
patchMethod = getString("Choose patching method: (size or number)", "size");
if (patchMethod == "size") {
    patchSize = getNumber("Enter patch size (pixels)", 128);
} else {
    numPatches = getNumber("Enter number of patches per dimension", 4);
}

// Gaussian smoothing (optional):
sigma = getNumber("Enter Gaussian smoothing sigma (0 for none)", 0);

// Output format:
outputFormat = getString("Choose output format (tiff, tif, jpeg, png)", "tiff");
validFormats = newArray("tiff", "tif", "jpeg", "png");

// Check if output format is valid
isValidFormat = false;
for (j = 0; j < validFormats.length; j++) {
    if (outputFormat == validFormats[j]) {
        isValidFormat = true;
        break;
    }
}
if (!isValidFormat) {
    exit("Invalid output format selected.");
}

// Batch processing of all images in the folder
list = getFileList(inputDir);
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".jpg") || endsWith(list[i], ".png")) {
        open(inputDir + list[i]);

        // Apply Gaussian smoothing (if sigma > 0)
        if (sigma > 0) {
            run("Gaussian Blur...", "sigma=" + sigma);
        }

        width = getWidth();
        height = getHeight();

        // Determine patch size:
        if (patchMethod == "size") {
            patchW = patchSize;
            patchH = patchSize;
            numCols = floor(width / patchW);
            numRows = floor(height / patchH);
        } else {
            numCols = numPatches;
            numRows = numPatches;
            patchW = floor(width / numCols);
            patchH = floor(height / numRows);
        }

        // Split and save patches:
        for (row = 0; row < numRows; row++) {
            for (col = 0; col < numCols; col++) {
                // Crop without closing the original image
                selectWindow(getTitle());
                x = col * patchW;
                y = row * patchH;
                makeRectangle(x, y, patchW, patchH);
                run("Duplicate...", "title=Patch");

                fileName = list[i];
                if (endsWith(fileName, ".tif") || endsWith(fileName, ".tiff")) {
                    fileName = replace(fileName, ".tif", "");
                    fileName = replace(fileName, ".tiff", "");
                } else if (endsWith(fileName, ".jpg")) {
                    fileName = replace(fileName, ".jpg", "");
                } else if (endsWith(fileName, ".png")) {
                    fileName = replace(fileName, ".png", "");
                }

                savePath = outputDir + fileName + "_patch_" + row + "_" + col + "." + outputFormat;
                run("16-bit");
                if (outputFormat == "tiff" || outputFormat == "tif") {
                    saveAs("Tiff", savePath);
                } else if (outputFormat == "jpeg") {
                    saveAs("Jpeg", savePath);
                } else if (outputFormat == "png") {
                    saveAs("PNG", savePath);
                }

                close(); 
            }
        }

        close(); 
    }
}
