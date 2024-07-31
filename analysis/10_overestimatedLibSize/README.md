# Overestimated Library

## Data preparation

Simply run `.../10_overestimatedLibSize/Lib_size_issue_Docker.R` without any argument:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/10_overestimatedLibSize/Lib_size_issue_Docker.R
```

Move the generated .csv file (`poolsize_sim_....csv`) from the `/docker/export` to the local directory.

Simply copy the whole file into the GraphPad file (`Poolsize_estim_prolif_dependence.pzf`).
