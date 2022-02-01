#!/usr/bin/python3

from PIL import Image
import numpy as np
from sklearn.cluster import DBSCAN
import glob
import os
import sys


def dbscan_annotation(annotation_dir, export_dir):
	for fn in glob.glob(os.path.join(annotation_dir, '*.png')):
		print(f"precessing {fn}")
		print(os.path.join(export_dir, fn.replace(annotation_dir, '')))
		with Image.open(fn) as im:
			#print(im)
			r, g, b = im.split()
			z = np.zeros(np.asarray(r).shape)
			for band_idx, band in enumerate([r, g]):
				ag = np.asarray(band)
				gp = ag.nonzero()
				print(np.shape(gp))
				if np.shape(gp)[1] == 0:
				  	continue
				#print(gp)
				gp = np.asarray(gp, dtype=np.double).T 
				#labels, core_samples_mask = DBSCAN(gp, eps=2, min_samples=1)
				labels = DBSCAN(eps=15, min_samples=10).fit(gp).labels_
				#print(labels.size)
				#print(labels.max())
				for i, elem in enumerate(np.uint(gp)):
					z[elem[0], elem[1]] = (127.0/(labels.max()+1) * (labels[i]+1))+128*band_idx if labels[i] >= 0 else 0
			Image.fromarray(z).convert('RGB').save(os.path.join(export_dir, fn.replace(annotation_dir, '')))
			
if __name__ == "__main__":
	if len(sys.argv) < 3:
	    print("Please provide a path to a annotation and output directory.")
	else:
	    adir = sys.argv[1]
	    odir = sys.argv[2]
	    print(f"annotation dir: {adir}\noutput dir: {odir}")
	    if not os.path.exists(odir):
	        os.mkdir(odir)
	    dbscan_annotation(adir, odir)
	   
