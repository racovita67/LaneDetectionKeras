"""Applies CLAHE to every training image in parallel (one worker process per CPU core).

Reads   TuLane/training/gt_image/*.png        (created by the dataset-split cells of LaneNet.ipynb)
Writes  TuLane/training/clahe_gt_image/*.png  (used by LaneNet.ipynb when flag_CLAHE = True)

Run from the repository root:  python Multiprocessing_C.py
"""
import os
import os.path as ops
import glob
import cv2

import multiprocessing
from multiprocessing import active_children
from multiprocessing import Process
from multiprocessing import Lock

from clahe import clahe

# function to execute in a new process
def task_process_img(idx, img_list, list_length, write_lock, write_path):
    while(idx.value < list_length):
        with idx.get_lock():
            i = idx.value
            idx.value += 1

        # Apply CLAHE using all 12 threads of CPU
        img_fp = img_list[i]
        img = cv2.imread(img_fp)
        ycbcr_image = cv2.cvtColor(img, cv2.COLOR_BGR2YCrCb)
        lum = ycbcr_image[:,:,0]
        eq_lum = clahe(lum, 9, 16)
        ycbcr_image[:,:,0] = eq_lum
        eq_img = cv2.cvtColor(ycbcr_image, cv2.COLOR_YCrCb2BGR)
        # Write image into folder
        
        clahe_fn = ops.join(write_path, ops.split(img_fp)[1])
        with write_lock:
            cv2.imwrite(clahe_fn, eq_img)
        print(
            f"[CLAHE] Processed {i+1}/{list_length}: "
            f"{ops.split(img_fp)[1]} -> {ops.split(clahe_fn)[1]}",
            flush=True,
        )
        
    else:
        return

 
if __name__ == '__main__':

    w_dir = os.getcwd()
    src_dir = ops.join(w_dir, ops.join('TuLane','splits'))
    training_fp = ops.join(ops.split(src_dir)[0], 'training')
    img_fp = ops.join(training_fp, 'gt_image')
    bin_fp = ops.join(training_fp, 'gt_binary_image')

    clahe_gt_image_fp = ops.join(training_fp, 'clahe_gt_image') 
    if ops.exists(training_fp) == True and ops.exists(clahe_gt_image_fp) == False:
        os.mkdir(clahe_gt_image_fp)
        
    img_path_list = glob.glob(ops.join(img_fp, "*.png"))
    if len(img_path_list) == 0:
        raise SystemExit(f"No images found in {img_fp}. Run the dataset-split cells of LaneNet.ipynb first, and start this script from the repository root.")
    else:
        print(f"[CLAHE] Input: found {len(img_path_list)} PNG images in {img_fp}", flush=True)
        print(f"[CLAHE] Output: writing enhanced images to {clahe_gt_image_fp}", flush=True)
    
    # Multiprocessing
    mpidx = multiprocessing.Value('i', lock=True)
    mpidx.value = 0
    write_lock = Lock() # Lock for writing into folder

    # Create child processes which will execute task_process_img() in parallel.
    cpu_count = multiprocessing.cpu_count()
    processes = [Process(target=task_process_img, args=(mpidx, img_path_list, len(img_path_list), write_lock, clahe_gt_image_fp)) for _ in range(cpu_count)]
    
    # Start the child processes
    for process in processes:
        process.start()
    
    # Get a list of all active child processes
    children = active_children()
    
    # Report a count of active children
    print(f"[CLAHE] Multiprocessing: started {len(processes)} workers ({len(children)} active)", flush=True)
    
    # Report each active worker in turn
    for child in children:
        print(f"[CLAHE] Worker PID {child.pid}: {child.name} ({child.exitcode})", flush=True)
    for process in processes:
        process.join()
    print(f"[CLAHE] Complete: {len(img_path_list)} images written to {clahe_gt_image_fp}", flush=True)
