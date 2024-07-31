# Unique Labeling

This simple code is for the calculation of "Unique cellular marking", which I mention in my Discussion part. The formula is from [Bystrykh & Belderbos, 2016](https://doi.org/10.1007/7651_2016_343).

Run `BC_UniqueLabeling.R` by passing the library size as the first argument and the number of cells to be transduced as the 2nd argument:

```sh
docker run -it --rm -v C:/your/path:/JD r_env Rscript /JD/analysis/11_uniqueLabeling/BC_UniqueLabeling.R 500 50
```

