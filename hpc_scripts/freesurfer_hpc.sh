#!/bin/bash
# PREP: navigate to your subjects directory in your project
# PREP: type ls */* and verify that the files you want to process are there
# usage: freesurfer_hpc.sh (from subject directory)

project=/scratch/tmhedr3/freesurfer_exp

# INITIALIZE OUTPUT DIRECTORIES
mkdir ${project}/output
for i in `ls ${project}/subjects`; do
        mkdir ${project}/output/${i}
        ln -s /share/apps/freesurfer/5.3.0/subjects/* ${project}/output/${i}
done

# JOB SUBMIT
for i in `ls ${project}/subjects`; do
        for j in `ls ${project}/subjects/${i}`; do
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
                recon-all -all -qcache -subjid $(echo $j | sed s/.nii//) -i ${project}/subjects/${i}/${j} -sd ${project}/output/${i}
EOF
                #cat ${script}
                qsub $script
        done
done
