#!/bin/bash

#module load pigz

set -e
set -x

if [ -z $1 ]; then
    echo "please specify root dir"
    exit 1
fi
root=$1

echo "running expand.sh"
timeout 1800 ./expand.sh $root

# Check to see if nifti/json (and bval/bvec) files are okay to use for ezBIDS
json_files=($(find $root -name "*.json"))
nifti_files=($(find $root -name "*.nii*"))
dwi_files=($(find $root -name "*.bv*"))

combined_files=("${json_files[@]}" "${nifti_files[@]}" "${dwi_files[@]}")
echo $combined_files
echo "number of combined files is: ${#combined_files[@]}"

if [ ${#combined_files[@]} -gt 0 ]; then
    bad_files=0

    for file in ${combined_files[@]}; do
        if [[ "$file" == *".bv"* ]]; then
            base_name=`ls $file | rev | cut -c5- | rev`
        elif [[ "$file" == *".json" ]]; then
            base_name=`ls $file | rev | cut -c5- | rev`
            if ! grep -q "ConversionSoftware" $file; then
                echo "bad file(s): $file"
                bad_files=$(($bad_files + 1))
            fi
        elif [[ "$file" == *".nii.gz" ]]; then
            base_name=`ls $file | rev | cut -c7- | rev`
        elif [[ "$file" == *".nii" ]]; then
            base_name=`ls $file | rev | cut -c4- | rev`
        fi

        num_base_name=`ls ${base_name}* | wc -l`
        if [ $num_base_name -ne 2 ] && [ $num_base_name -ne 4 ]; then
            echo "bad file(s): $file"
            bad_files=$(($bad_files + 1))
        fi
    done
fi


# If any files aren't usable for ezBIDS, we remove ALL files and default to the dicoms
echo ""
echo "Number of files unuseable for ezBIDS: $bad_files"
if [ $bad_files -gt 0 ]; then
    for file in ${combined_files[@]}; do
        rm -rf $file
    done
fi

# If there are usable .nii files, compress them to .nii.gz
nii_files=$(find $root -name "*.nii")
if [ ${#nii_files[@]} ]; then
	for nii in ${nii_files[@]}; do
		gzip $nii
	done
fi

echo "processing $root"

echo "finding dicom directories"
./find_dicomdir.py $root > $root/dcm2niix.list
cat $root/dcm2niix.list

echo "number of combined files is: ${#combined_files[@]}"
echo "number of bad files is: $bad_files"

if [ ${#combined_files[@]} -eq 0 ] || [ $bad_files -ne 0 ]; then
	echo "running dcm2niix"
	true > $root/dcm2niix.done
	function d2n {
	    path=$1
	    echo "----------------------- $path ------------------------"
	    timeout 3600 dcm2niix -v 1 -ba n -z o -f 'time-%t-sn-%s' $path
	    ret=$!
	    if [ $ret == 2 ]; then
	        #probably empty directory?
	        echo "skipping"
	        return
	    fi
	    if [ $ret != 0]; then
	        echo "dcm2niix failed"
	        exit $ret
	    fi
	    echo $1 >> $root/dcm2niix.done
	}
	export -f d2n
	cat $root/dcm2niix.list | parallel --linebuffer --wd $root -j 6 d2n {}
fi

#find products
(cd $root && find . -type f \( -name "*.json" -o -name "*.nii.gz" -o -name "*.bval" -o -name "*.bvec" \) > list)
cat $root/list

if [ ! -s $root/list ]; then
    echo "couldn't find any dicom files. aborting"
    exit 1
fi

echo "running analyzer (should take a minute)"
timeout 600 ./analyzer/run.sh $root

echo "done preprocessing"


