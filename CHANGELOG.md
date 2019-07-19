# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- Proper default options for the parallelized validation 
- `ShEx.ShapeMap.decode!/2`
- Various checks during schema parsing and creation:
	- unsatisfied references
	- collisions of triple expression labels with shape expression labels

### Fixed

- Resolving queries in a query ShapeMap sometimes failed when queries had no results  


[Compare v0.1.0...HEAD](https://github.com/marcelotto/shex-ex/compare/v0.1.0...HEAD)



## v0.1.0 - 2019-07-15

Initial release
