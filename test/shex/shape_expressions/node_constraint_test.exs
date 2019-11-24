defmodule ShEx.NodeConstraintTest do
  use ExUnit.Case
  doctest ShEx.NodeConstraint

  alias ShEx.NodeConstraint, as: NC
  alias ShEx.NodeConstraint.{StringFacets, NumericFacets, Values}

  alias ShEx.ShapeMap.Association

  alias ShEx.Violation.{
    NodeKindConstraint,
    DatatypeConstraint,
    StringFacetConstraint,
    NumericFacetConstraint,
    ValuesConstraint
  }

  alias RDF.NS.XSD
  import RDF.Sigils

  @example_iri RDF.iri("http://example.com/")
  @example_string RDF.string("http://example.com/")
  @example_integer RDF.integer(42)
  @example_decimal RDF.decimal(3.14)
  @example_double RDF.double(3.14)

  describe "satisfies/2" do
    test "iri node kind constraint with satisfying node" do
      [
        @example_iri
      ]
      |> Enum.each(fn node ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(%NC{node_kind: "iri"}, Association.new(node, :start))
      end)
    end

    test "iri node kind constraint with unsatisfying node" do
      [
        RDF.bnode(),
        @example_string,
        @example_integer,
        RDF.true(),
        RDF.false()
      ]
      |> Enum.each(fn node ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%NodeKindConstraint{node_kind: "iri", node: ^node}]
               } = NC.satisfies(%NC{node_kind: "iri"}, Association.new(node, :start))
      end)
    end

    test "bnode node kind constraint with satisfying node" do
      [
        RDF.bnode()
      ]
      |> Enum.each(fn node ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(%NC{node_kind: "bnode"}, Association.new(node, :start))
      end)
    end

    test "bnode node kind constraint with unsatisfying node" do
      [
        @example_iri,
        @example_string,
        @example_integer,
        RDF.true(),
        RDF.false()
      ]
      |> Enum.each(fn node ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%NodeKindConstraint{node_kind: "bnode", node: ^node}]
               } = NC.satisfies(%NC{node_kind: "bnode"}, Association.new(node, :start))
      end)
    end

    test "literal node kind constraint with satisfying node" do
      [
        @example_string,
        @example_integer,
        RDF.true(),
        RDF.false()
      ]
      |> Enum.each(fn node ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(%NC{node_kind: "literal"}, Association.new(node, :start))
      end)
    end

    test "literal node kind constraint with unsatisfying node" do
      [
        @example_iri,
        RDF.bnode()
      ]
      |> Enum.each(fn node ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%NodeKindConstraint{node_kind: "literal", node: ^node}]
               } = NC.satisfies(%NC{node_kind: "literal"}, Association.new(node, :start))
      end)
    end

    test "nonliteral node kind constraint with satisfying node" do
      [
        @example_iri,
        RDF.bnode()
      ]
      |> Enum.each(fn node ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(%NC{node_kind: "nonliteral"}, Association.new(node, :start))
      end)
    end

    test "nonliteral node kind constraint with unsatisfying node" do
      [
        @example_string,
        @example_integer,
        RDF.true(),
        RDF.false()
      ]
      |> Enum.each(fn node ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%NodeKindConstraint{node_kind: "nonliteral", node: ^node}]
               } = NC.satisfies(%NC{node_kind: "nonliteral"}, Association.new(node, :start))
      end)
    end

    test "datatype constraint with satisfying node" do
      [
        {@example_string, XSD.string()},
        {@example_integer, XSD.integer()},
        {RDF.false(), XSD.boolean()},
        {RDF.true(), XSD.boolean()},
        {~L"42", XSD.integer()}
      ]
      |> Enum.each(fn {node, datatype} ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(%NC{datatype: datatype}, Association.new(node, :start))
      end)
    end

    test "datatype constraint with unsatisfying node" do
      [
        {@example_iri, XSD.string()},
        {RDF.bnode(), XSD.string()},
        {RDF.true(), XSD.string()},
        {@example_integer, XSD.string()},
        {@example_integer, XSD.boolean()},
        {@example_string, XSD.integer()},
        {RDF.boolean("10"), XSD.boolean()}
      ]
      |> Enum.each(fn {node, datatype} ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%DatatypeConstraint{datatype: ^datatype, node: ^node}]
               } = NC.satisfies(%NC{datatype: datatype}, Association.new(node, :start))
      end)
    end

    test "string facet constraint with satisfying node" do
      [
        {~L"foo", %{length: 3}},
        {~L"foo", %{minlength: 1}},
        {~L"foo", %{minlength: 1, maxlength: 3}},
        {@example_integer, %{length: 2}},
        {RDF.false(), %{minlength: 2}},
        {RDF.true(), %{maxlength: 5}},
        {@example_iri, %{minlength: 3}},
        {RDF.bnode("foo"), %{length: 3}},
        {@example_iri, %{pattern: "example\.com"}},
        {@example_iri, %{pattern: "example.com", flags: "q"}},
        {@example_iri, %{pattern: "EXAMPLE.com", flags: "qi"}},
        {~L"\/\t\n\r\-\\\u0061\u{01D4B8}",
         %{pattern: "^\\\\/\\\\t\\\\n\\\\r\\\\-\\\\\\\\\\\\u0061\\\\U0001D4B8$"}}
      ]
      |> Enum.each(fn {node, xs_facets} ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(
                   %NC{string_facets: StringFacets.new(xs_facets)},
                   Association.new(node, :start)
                 )
      end)
    end

    test "string facet constraint with unsatisfying node" do
      [
        {~L"foo", %{minlength: 1, maxlength: 2}},
        {@example_iri, %{pattern: "foo"}}
      ]
      |> Enum.each(fn {node, xs_facets} ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%StringFacetConstraint{node: ^node}]
               } =
                 NC.satisfies(
                   %NC{string_facets: StringFacets.new(xs_facets)},
                   Association.new(node, :start)
                 )
      end)
    end

    test "numeric facet constraint with satisfying node" do
      [
        {@example_integer, %{mininclusive: 41}},
        {@example_integer, %{mininclusive: 42}},
        {@example_integer, %{minexclusive: 41}},
        {@example_integer, %{maxinclusive: 42}},
        {@example_integer, %{maxinclusive: 43}},
        {@example_integer, %{maxexclusive: 43}},
        {@example_integer, %{totaldigits: 2}},
        {@example_integer, %{totaldigits: 3}},
        {@example_integer, %{fractiondigits: 0}},
        {@example_integer, %{fractiondigits: 5}},
        {@example_decimal, %{mininclusive: Decimal.from_float(3.14)}},
        {@example_decimal, %{totaldigits: 3}},
        {@example_decimal, %{fractiondigits: 2}},
        {@example_decimal, %{fractiondigits: 3}}
      ]
      |> Enum.each(fn {node, xs_facets} ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(
                   %NC{numeric_facets: NumericFacets.new(xs_facets)},
                   Association.new(node, :start)
                 )
      end)
    end

    test "numeric facet constraint with unsatisfying node" do
      [
        {@example_integer, %{mininclusive: 43}},
        {@example_integer, %{minexclusive: 42}},
        {@example_integer, %{maxinclusive: 41}},
        {@example_integer, %{maxexclusive: 42}},
        {@example_integer, %{totaldigits: 1}},
        {@example_decimal, %{totaldigits: 2}},
        {@example_decimal, %{fractiondigits: 1}},
        {@example_decimal, %{minexclusive: Decimal.from_float(3.14)}},
        {@example_double, %{totaldigits: 3}},
        {@example_double, %{fractiondigits: 3}},
        {@example_double, %{mininclusive: RDF.double(3.14)}},
        {@example_string, %{mininclusive: 1}},
        {RDF.false(), %{maxinclusive: 1}},
        {RDF.true(), %{minexclusive: 1}},
        {@example_iri, %{maxexclusive: 1}},
        {RDF.bnode("foo"), %{totaldigits: 1}}
      ]
      |> Enum.each(fn {node, xs_facets} ->
        assert %Association{
                 node: ^node,
                 status: :nonconformant,
                 reason: [%NumericFacetConstraint{node: ^node}]
               } =
                 NC.satisfies(
                   %NC{numeric_facets: NumericFacets.new(xs_facets)},
                   Association.new(node, :start)
                 )
      end)
    end

    test "values constraint without exclusion and satisfying node" do
      [
        {@example_iri, [@example_iri]},
        {@example_iri, [RDF.iri("http://example.com/foo"), @example_iri]},
        {~L"foo", [~L"foo"]},
        {~L"foo", [~L"foo", ~L"bar"]},
        {@example_integer, [@example_integer]},
        {~L"foo"en, [%{type: "Language", languageTag: "en"}]},
        {~L"foo"EN, [%{type: "Language", languageTag: "EN"}]},
        {~L"foo"en, [%{type: "Language", languageTag: ""}]},
        {@example_iri, [%{type: "IriStem", stem: @example_iri}]},
        {RDF.iri("http://example.com/foo"), [%{type: "IriStem", stem: @example_iri}]},
        {~L"foo", [%{type: "LiteralStem", stem: "foo"}]},
        {~L"foo", [%{type: "LiteralStem", stem: "fo"}]},
        {~L"foo"en, [%{type: "LiteralStem", stem: "fo"}]},
        {@example_integer, [%{type: "LiteralStem", stem: "4"}]},
        {~L"foo"en, [%{type: "LanguageStem", stem: "en"}]},
        {RDF.string("foo", language: "de-CH"), [%{type: "LanguageStem", stem: "de"}]},
        {RDF.string("foo", language: "de-CH"), [%{type: "LanguageStem", stem: "de-ch"}]}
      ]
      |> Enum.each(fn {node, value_set_values} ->
        assert %Association{node: ^node, status: :conformant} =
                 NC.satisfies(
                   %NC{values: Values.new(value_set_values)},
                   Association.new(node, :start)
                 )
      end)
    end
  end

  test "values constraint without exclusion and unsatisfying node" do
    [
      {~L"foo", [~L"bar"]},
      {~L"foo", [~L"foo"de]},
      {~L"foo", [~L"foo"de, ~L"bar"]},
      {~L"foo"en, [%{type: "Language", languageTag: "de"}]},
      {~L"foo", [%{type: "Language", languageTag: ""}]},
      {RDF.iri("http://example.org/foo"), [%{type: "IriStem", stem: @example_iri}]},
      {~L"foo", [%{type: "LiteralStem", stem: "oo"}]},
      {@example_integer, [%{type: "LiteralStem", stem: "2"}]},
      {~L"foo"en, [%{type: "LanguageStem", stem: "de"}]}
    ]
    |> Enum.each(fn {node, value_set_values} ->
      assert %Association{
               node: ^node,
               status: :nonconformant,
               reason: [%ValuesConstraint{node: ^node} | _]
             } =
               NC.satisfies(
                 %NC{values: Values.new(value_set_values)},
                 Association.new(node, :start)
               )
    end)
  end

  test "values constraint with exclusion and satisfying node" do
    [
      {@example_iri,
       [%{type: "IriStemRange", stem: @example_iri, exclusions: [RDF.iri("http://example.org/")]}]},
      {RDF.iri("http://example.com/foo"),
       [
         %{
           type: "IriStemRange",
           stem: @example_iri,
           exclusions: [%{type: "IriStem", stem: RDF.iri("http://example.com/foo-")}]
         }
       ]},
      {RDF.iri("http://example.com/foo"),
       [
         %{
           type: "IriStemRange",
           stem: @example_iri,
           exclusions: [%{type: "IriStem", stem: "http://example.com/foo-"}]
         }
       ]},
      {~L"foo", [%{type: "LiteralStemRange", stem: "fo", exclusions: [~L"foo-bar"]}]},
      {~L"foo",
       [
         %{
           type: "LiteralStemRange",
           stem: "fo",
           exclusions: [%{type: "LiteralStem", stem: "foo-"}]
         }
       ]},
      {~L"foo"en, [%{type: "LanguageStemRange", stem: "en", exclusions: [~L"en-US"]}]},
      {~L"foo"en, [%{type: "LanguageStemRange", stem: "", exclusions: [~L"en-US"]}]},
      {~L"foo",
       [%{type: "LanguageStemRange", stem: %{type: "Wildcard"}, exclusions: [~L"foo-bar"]}]},
      {@example_iri,
       [
         %{
           type: "IriStemRange",
           stem: %{type: "Wildcard"},
           exclusions: [RDF.iri("http://example.org/")]
         }
       ]},
      {~L"foo",
       [%{type: "LiteralStemRange", stem: %{type: "Wildcard"}, exclusions: [~L"foo-bar"]}]},
      {~L"foo"en,
       [%{type: "LanguageStemRange", stem: %{type: "Wildcard"}, exclusions: [~L"foo-bar"]}]}
    ]
    |> Enum.each(fn {node, value_set_values} ->
      assert %Association{node: ^node, status: :conformant} =
               NC.satisfies(
                 %NC{values: Values.new(value_set_values)},
                 Association.new(node, :start)
               )
    end)
  end

  test "values constraint with exclusion and unsatisfying node" do
    [
      {@example_iri, [%{type: "IriStemRange", stem: @example_iri, exclusions: [@example_iri]}]},
      {RDF.iri("http://example.com/foo-bar"),
       [
         %{
           type: "IriStemRange",
           stem: @example_iri,
           exclusions: [%{type: "IriStem", stem: RDF.iri("http://example.com/foo-")}]
         }
       ]},
      {~L"foo-bar", [%{type: "LiteralStemRange", stem: "fo", exclusions: [~L"foo-bar"]}]},
      {~L"foo-bar",
       [
         %{
           type: "LiteralStemRange",
           stem: "fo",
           exclusions: [%{type: "LiteralStem", stem: "foo-"}]
         }
       ]},
      {~L"v1", [%{type: "LiteralStemRange", stem: "v", exclusions: ["v1", "v2"]}]},
      {@example_iri,
       [%{type: "IriStemRange", stem: %{type: "Wildcard"}, exclusions: [@example_iri]}]},
      {~L"foo-bar",
       [
         %{
           type: "LiteralStemRange",
           stem: %{type: "Wildcard"},
           exclusions: [%{type: "LiteralStem", stem: "foo-"}]
         }
       ]},
      {RDF.string("foo", language: "de-CH"),
       [
         %{
           type: "LanguageStemRange",
           stem: "de",
           exclusions: [%{type: "LanguageStem", stem: "de-CH"}]
         }
       ]},
      {RDF.string("foo", language: "de-CH"),
       [%{type: "LanguageStemRange", stem: "de", exclusions: ["de-CH"]}]}
    ]
    |> Enum.each(fn {node, value_set_values} ->
      assert %Association{
               node: ^node,
               status: :nonconformant,
               reason: [%ValuesConstraint{node: ^node, constraint_type: :exclusion}]
             } =
               NC.satisfies(
                 %NC{values: Values.new(value_set_values)},
                 Association.new(node, :start)
               )
    end)
  end
end
