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

### Example
[test_split_singleim](./test_split_singleim/) contains an example directory structure with one image, the corresponding annotation data of [A Crop/Weed Field Image Dataset](https://github.com/cwfid/dataset) and the images of separated single plants.

Run `ruby seperate_plants.rb -d../test_split_singleim/` to test the setup. This should result in a new `plants` directory equivalent to [test_split_singleim/plants](./test_split_singleim/plants).

## DBSCAN
Datasets which do not include a polygon annotation file can be separated by a density based clustering algorithm. The separation is split up into two steps. The first script clusters the plants in the annotation masks. The second part crops the plants based on the clustered annotations masks.
1. DBSCAN: Run `python3 dbscan_plants.py {annotation_dir} {output_dir}` with `annotation_dir= ../test_split_singleim/annotations/` and `ouput_dir= dbscan` to test the script. The result should be a PNG file where each plant in the annotation mask has a different shade of gray.
2. Separate the Clustered Annotation Masks: Run `ruby seperate_dbscan_annotation.rb -d{dir}` with `dir = ../test_split_singleim/` containing the subdirectories `dbscan` (output of step 1) and `images` (origianl images). 

# Database Connection 
In order to be able to access the different plants in a structured and simple way, the data is stored in a sqlite database. 
The following example inserts the data separated by the *Polygon Method* into a database and copies the images to another directory where all the plant images are stored.  

`ruby db_connector.rb --dir_dest=../test_split_singleim/croppedplants --dir_plants=../test_split_singleim/plants/ --path_db=../test_split_singleim/plant.db --px_per_mm=8.95 --age=0 --notes="carrot dataset" --crop=carrot`
