# ExaPowerIO.jl

ExaPowerIO is a minimal IO library for the [Matpower](https://matpower.app/manual/matpower/DataFileFormat.html) file format.

![CI](https://github.com/MadNLP/ExaPowerIO.jl/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![doc](https://img.shields.io/badge/docs-stable-blue.svg)](https://madsuite.org/ExaPowerIO.jl/stable) 
[![doc](https://img.shields.io/badge/docs-dev-blue.svg)](https://madsuite.org/ExaPowerIO.jl/dev) 
[![coverage](https://codecov.io/gh/MadNLP/ExaPowerIO.jl/branch/main/graph/badge.svg?token=MBxH2AAu8Z)]

DICLAIMER: ExaPowerIO is in active development. There may be missing features, documentation, or other issues.
If you experience any of these, please open [Issues](https://github.com/MadNLP/ExaPowerIO.jl/issues), or [Pull Requests](https://github.com/MadNLP/ExaPowerIO.jl/pulls)

### Usage
If you are interested in trying ExaPowerIO, please see the [Usage Documentation](https://madsuite.org/ExaPowerIO.jl/stable/user/) for information on using the functions / structs exported by ExaPowerIO.

### Contributing
If you wish to contribute to ExaPowerIO, please see the [Developer Documentation](https://madsuite.org/ExaPowerIO.jl/stable/dev/) for information on project structure, as well as running benchmarks / tests.

### Alternatives
The main alternative to ExaPowerIO is [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl), a monolithic repository which:
- parses and processes Matpower as well as PTI files
- exports formulations for various ACOPF problems
- includes tools to help solve these problems.
Developers wishing to utilize only 1 or 2 of these utilities may find PowerModels bloated.

ExaPowerIO.jl due to its focused nature has superior performance to PowerModels. As seen, ExaPowerIO outperforms PowerModels by a factor of 30 to 40 in both allocation and timing.
