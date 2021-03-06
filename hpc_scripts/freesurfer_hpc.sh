#!/bin/bash

function usage
{
    echo ""
    echo "  Submit many freesurfer jobs to the cluster."
    echo "  The input subject directory must contain group subdirectories, which"
    echo "  in turn will contain the T1-anatomical NIfTI images for each associated"
    echo "  group. If you only have one group, you still need a subdirectory for"
    echo "  your images. By default, the program will print test output so you can"
    echo "  verify everything is interpreted correctly."
    echo ""
    echo "Use -r to submit the jobs."
    echo ""
    echo "Usage: "
    echo "   freesurfer_hpc <options> -p <absolute path to project directory> -s <name of subjects directory> -o <name of output directory>"
    echo ""
    echo "OPTIONS:"
    echo "   -r        Submit the jobs."
    echo "   -p <project directory path>      This must be an absolute path, starting from root. Example: /home/tmhabc/scratch/freesurfer_exp"
    echo "   -d <data directory name>         This is the name of your data directory,           Example: vascular_dementia"
    echo "   -o <output directory name>       This is the name of your output directory,         Example: results"
    echo ""
    
}

popt=0
sopt=0
oopt=0
RUN=0
while getopts "rp:d:o: h" o ; do
        case $o in
                r ) RUN=1;;
                p ) project=$OPTARG; popt=1;;
                d ) subjects=$OPTARG; sopt=1;;
                o ) output=$OPTARG; oopt=1;;
                h ) usage; exit 0;;        
                \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
                :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
                *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
        esac
done

if [ $popt -eq 0 -o $sopt -eq 0 -o $oopt -eq 0 ]; then
        echo "    -p, -d, and -o are required arguments."
        exit 1
fi

# INITIALIZE OUTPUT DIRECTORIES
if [ $RUN -eq 1 ]; then
    if [ -d ${project}/${output} ]; then
        echo "    'output' directory already exists."
        exit 1
    fi
    mkdir ${project}/${output}
    for i in `ls ${project}/${subjects}`; do
        mkdir ${project}/${output}/${i}
        ln -s /share/apps/freesurfer/5.3.0/subjects/* ${project}/${output}/${i}
    done
fi

# JOB SUBMIT
for i in `ls ${project}/${subjects}`; do
        for j in `ls ${project}/${subjects}/${i}`; do
                echo "   *** SUBJECT: ${j} ***"
                script=$(mktemp)
                cat > ${script} <<EOF
                #!/bin/sh
                #PBS -q default
                #PBS -N $j
                #PBS -l nodes=1:ppn=1
                #PBS -l walltime=01:00:00:00
                #PBS -e localhost:${project}/runlogs
                #PBS -o localhost:${project}/runlogs
                #PBS -S /bin/bash
                module load freesurfer/5.3.0
                source /share/apps/freesurfer/5.3.0/SetUpFreeSurfer.sh
                recon-all -all -qcache -subjid $(echo $j | sed s/.nii//) -i ${project}/${subjects}/${i}/${j} -sd ${project}/${output}/${i}
EOF

                if [ $RUN -eq 1 ]; then
                        qsub $script
                else
                        cat $script
                fi
        done
done
