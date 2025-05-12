## If you're on a system with Singularity (now Apptainer) installed:

``` bash
sudo singularity build bwa_sambamba.sif Singularity.def
```

## If you're on an HPC (no sudo), use:

``` bash
singularity build --remote bwa_sambamba.sif Singularity.def
```

## Update your script to execute within the container:

``` bash
singularity exec bwa_sambamba.sif bash bwa_markdup_mapper.sh samples.txt
```

## Or for SLURM integration:

``` bash
srun singularity exec bwa_sambamba.sif bash bwa_markdup_mapper.sh samples.txt
```
