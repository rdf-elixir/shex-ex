# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

This version just upgrades to RDF.ex 0.8. With its support for all derived numeric datatypes comes now  
full support for all datatypes in ShEx.ex. 

[Compare v0.1.2...HEAD](https://github.com/rdf-elixir/shex-ex/compare/v0.1.2...HEAD)



## v0.1.2 - 2019-12-15

- Upgrade to RDF.ex 0.7

[Compare v0.1.1...v0.1.2](https://github.com/rdf-elixir/shex-ex/compare/v0.1.1...v0.1.2)



## v0.1.1 - 2019-07-20

### Added

- Proper default options for the parallelized validation 
- `ShEx.ShapeMap.decode!/2`
- Various checks during schema parsing and creation:
	- unsatisfied references
	- collisions of triple expression labels with shape expression labels

### Changed

- Parallelization is now turned on automatically for all query ShapeMaps and  
  fixed ShapeMaps with more than 10 associations

### Fixed

- Resolving queries in a query ShapeMap sometimes failed when queries had no results  


[Compare v0.1.0...v0.1.1](https://github.com/rdf-elixir/shex-ex/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2019-07-15

Initial release
