defmodule ShExTest do
  use ExUnit.Case
  doctest ShEx

  import RDF.Sigils

  @example_data RDF.Turtle.read_string!("""
                PREFIX ex: <http://ex.example/#>
                PREFIX inst: <http://example.com/users/>
                PREFIX school: <http://school.example/#>
                PREFIX foaf: <http://xmlns.com/foaf/0.1/>

                inst:Alice foaf:age 13 ;
                  ex:hasGuardian inst:Person2, inst:Person3 .

                inst:Bob foaf:age 15 ;
                  ex:hasGuardian inst:Person4 .

                inst:Claire foaf:age 12 ;
                  ex:hasGuardian inst:Person5 .

                inst:Don foaf:age 14 .
                """)

  @example_schema ShEx.ShExC.decode!("""
                  PREFIX ex: <http://ex.example/#>
                  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
                  PREFIX school: <http://school.example/#>
                  PREFIX foaf: <http://xmlns.com/foaf/0.1/>

                  school:enrolleeAge xsd:integer MinInclusive 13 MaxInclusive 20

                  school:Enrollee {
                    foaf:age @school:enrolleeAge ;
                    ex:hasGuardian IRI {1,2}
                  }
                  """)

  @example_shape_map ShEx.ShapeMap.new(%{
                       ~I<http://example.com/users/Alice> => ~I<http://school.example/#Enrollee>,
                       ~I<http://example.com/users/Bob> => ~I<http://school.example/#Enrollee>,
                       ~I<http://example.com/users/Claire> => ~I<http://school.example/#Enrollee>,
                       ~I<http://example.com/users/Don> => ~I<http://school.example/#Enrollee>
                     })

  @example_result_shape_map %ShEx.ShapeMap{
    type: :result,
    conformant: [
      %ShEx.ShapeMap.Association{
        node: ~I<http://example.com/users/Alice>,
        shape: ~I<http://school.example/#Enrollee>,
        status: :conformant
      },
      %ShEx.ShapeMap.Association{
        node: ~I<http://example.com/users/Bob>,
        shape: ~I<http://school.example/#Enrollee>,
        status: :conformant
      }
    ],
    nonconformant: [
      %ShEx.ShapeMap.Association{
        node: ~I<http://example.com/users/Claire>,
        shape: ~I<http://school.example/#Enrollee>,
        status: :nonconformant,
        reason: [
          %ShEx.Violation.MinCardinality{
            cardinality: 0,
            triple_expression: %ShEx.EachOf{
              annotations: nil,
              expressions: [
                %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: nil,
                  min: nil,
                  predicate: ~I<http://xmlns.com/foaf/0.1/age>,
                  sem_acts: nil,
                  value_expr: ~I<http://school.example/#enrolleeAge>
                },
                %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: 2,
                  min: 1,
                  predicate: ~I<http://ex.example/#hasGuardian>,
                  sem_acts: nil,
                  value_expr: %ShEx.NodeConstraint{
                    datatype: nil,
                    id: nil,
                    node_kind: "iri",
                    numeric_facets: nil,
                    string_facets: nil,
                    values: nil
                  }
                }
              ],
              id: nil,
              max: nil,
              min: nil,
              sem_acts: nil
            },
            triple_expression_violations: [
              %ShEx.Violation.MinCardinality{
                cardinality: 0,
                triple_expression: %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: nil,
                  min: nil,
                  predicate: ~I<http://xmlns.com/foaf/0.1/age>,
                  sem_acts: nil,
                  value_expr: ~I<http://school.example/#enrolleeAge>
                },
                triple_expression_violations: [
                  %ShEx.Violation.NumericFacetConstraint{
                    facet_type: :mininclusive,
                    facet_value: %RDF.Literal{
                      value: Decimal.from_float(13.0),
                      datatype: ~I<http://www.w3.org/2001/XMLSchema#decimal>
                    },
                    node: %RDF.Literal{
                      value: 12,
                      datatype: ~I<http://www.w3.org/2001/XMLSchema#integer>
                    }
                  }
                ]
              }
            ]
          }
        ]
      },
      %ShEx.ShapeMap.Association{
        node: ~I<http://example.com/users/Don>,
        shape: ~I<http://school.example/#Enrollee>,
        status: :nonconformant,
        reason: [
          %ShEx.Violation.MinCardinality{
            cardinality: 0,
            triple_expression: %ShEx.EachOf{
              annotations: nil,
              expressions: [
                %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: nil,
                  min: nil,
                  predicate: ~I<http://xmlns.com/foaf/0.1/age>,
                  sem_acts: nil,
                  value_expr: ~I<http://school.example/#enrolleeAge>
                },
                %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: 2,
                  min: 1,
                  predicate: ~I<http://ex.example/#hasGuardian>,
                  sem_acts: nil,
                  value_expr: %ShEx.NodeConstraint{
                    datatype: nil,
                    id: nil,
                    node_kind: "iri",
                    numeric_facets: nil,
                    string_facets: nil,
                    values: nil
                  }
                }
              ],
              id: nil,
              max: nil,
              min: nil,
              sem_acts: nil
            },
            triple_expression_violations: [
              %ShEx.Violation.MinCardinality{
                cardinality: 0,
                triple_expression: %ShEx.TripleConstraint{
                  annotations: nil,
                  id: nil,
                  inverse: nil,
                  max: 2,
                  min: 1,
                  predicate: ~I<http://ex.example/#hasGuardian>,
                  sem_acts: nil,
                  value_expr: %ShEx.NodeConstraint{
                    datatype: nil,
                    id: nil,
                    node_kind: "iri",
                    numeric_facets: nil,
                    string_facets: nil,
                    values: nil
                  }
                },
                triple_expression_violations: []
              }
            ]
          }
        ]
      }
    ]
  }

  describe "validate/4" do
    test "ShEx primer example" do
      assert ShEx.validate(@example_data, @example_schema, @example_shape_map) ==
               @example_result_shape_map
    end

    test "ShEx primer example in parallel" do
      assert result_shape_map =
               ShEx.validate(@example_data, @example_schema, @example_shape_map,
                 parallel: true,
                 max_demand: 1
               )

      assert MapSet.new(result_shape_map.conformant) ==
               MapSet.new(@example_result_shape_map.conformant)

      assert MapSet.new(result_shape_map.nonconformant) ==
               MapSet.new(@example_result_shape_map.nonconformant)

      assert %ShEx.ShapeMap{result_shape_map | conformant: [], nonconformant: []} ==
               %ShEx.ShapeMap{@example_result_shape_map | conformant: [], nonconformant: []}
    end
  end
end
