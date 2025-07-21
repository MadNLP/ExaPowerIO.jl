# Developer Documentation
This documentation covers how to:
1. Run the projects test suite
2. Run the projets benchmarks
3. Update and build documentation of ExaPowerIO

### Test suite
ExaPowerIO's test suite can be run with the following command:

```bash
julia --project=. -e 'using Pkg; Pkg.test("ExaPowerIO")'
```

The tests compare output from parsing with PowerModels.jl. We realize this is suboptimal, and would encourage PR's changing this.

### Benchmarks
ExaPowerIO's benchmarking suite can be run with the following command:

```bash
julia --project=benchmark benchmark/runbenchmarks.jl
```

Additionally, there are three available flags which can be passed to the benchmarking script:
- ```--compare``` can be passed to output a comparison with PowerModels.jl's parser
- ```--intermediate``` can be passed to output the timing of the two stages of the parser (text -> struct, struct -> named tuple if applicable)
- ```--num-samples <k>``` or ```-n <k>``` can be passed to set the number of samples taken of each case in the benchmark. The default value is 10.

### Documentation
ExaPowerIO uses [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) for its documentation. To build and deploy the documentation locally:

```bash
cd docs
julia --project -e 'include("make.jl"); using LiveServer; serve(dir="build")'
```

The documentation should then be visible at localhost:8000.
