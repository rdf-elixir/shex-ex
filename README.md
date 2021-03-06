<img src="shex-logo.png" align="right" />

# ShEx.ex

[![CI](https://github.com/rdf-elixir/shex-ex/workflows/CI/badge.svg?branch=master)](https://github.com/rdf-elixir/shex-ex/actions?query=branch%3Amaster+workflow%3ACI)
[![Hex.pm](https://img.shields.io/hexpm/v/shex.svg?style=flat-square)](https://hex.pm/packages/shex)


An implementation of the [ShEx] specification in Elixir.

It allows to run validations specified in the Shape Expressions language (ShEx) on RDF graphs.

> Shape Expressions (ShEx) is a language for describing RDF graph structures. A ShEx schema prescribes conditions that RDF data graphs must meet in order to be considered "conformant": which subjects, predicates, and objects may appear in a given graph, in what combinations and with what cardinalities and datatypes. 

-- [Shape Expressions (ShEx) Primer](http://shex.io/shex-primer/#tripleConstraints)

The validation of larger amounts of nodes is done in parallel.

The API documentation can be found [here](https://hexdocs.pm/shex/). For a guide and more information about ShEx.ex and it's related projects, go to <https://rdf-elixir.dev>.


## Limitations

- the following ShEx features are not implemented yet:
    - invalid shape expression references in negations are not checked
    - imports
    - external shapes
    - annotations
    - semantic actions
- greedy matching
- non-ascii characters in regular expressions are not fully supported yet



## Consulting and Partnership

If you need help with your Elixir and Linked Data projects, just contact <info@cokron.com> or visit <https://www.cokron.com/kontakt>



## License and Copyright

(c) 2019-2020 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.



[ShEx]: http://shex.io/
