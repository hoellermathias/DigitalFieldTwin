# Dataset Separation
Two methods to decompose a dataset have been implemented. The method with the polygons is preferred if the data is available. The big advantage is that the plants can be cleanly separated from each other, this is not the case with the DBSCAN variant, when plants of the same species overlap. 

## Polygon 
The following example annotation yaml file is from [A Crop/Weed Field Image Dataset](https://github.com/cwfid/dataset). The polygons drawn by the annotator are combined with the annotation mask to extract the plants of the image.  
Structure of the input:
Path to Parent Dir (`-dPATH`)
```
|-- annotations
    |-- *N*_image.png
|-- images
    |-- *N*_annotation.png
    |-- *N*_annotation.yaml
```
The images and annotations have to be PNG files. The script uses the namingscheme of [A Crop/Weed Field Image Dataset](https://github.com/cwfid/dataset). 
```
filename: 001_image.png
annotation:
- type: weed
  points:
    x: [810.0, 841.0, 846.0, 926.0, 956.0, 1054.0, 1175.0, 1161.0, 1010.0, 971.0,
      948.0, 937.0, 909.0, 837.0]
    y: [225.0, 234.0, 266.0, 338.0, 408.0, 422.0, 317.0, 230.0, 126.0, 114.0, 130.0,
      167.0, 170.0, 169.0]
```
Structure of the Output:
The individual plant images are stored in the `plants` directory from which the script is called.
The naming convention of the output images is: `{N}_{sequential number}_{plant type}_{width ratio}.png`.