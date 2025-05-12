# processing-sequencing-data
This repository contains a series of scripts/tools for handling/processing sequencing data.

## `sbatch` example for the `bwa_markdup_mapper.sh` wrapper.

```
sbatch -p [partition] -c [cores] --mem= [RAM] -t [72:00:00] --job-name=[name] doMapping-HPC.sh sample_names_list.txt
```
