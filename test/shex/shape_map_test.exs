defmodule ShEx.ShapeMapTest do
  use ExUnit.Case
  doctest ShEx.ShapeMap

  import RDF.Sigils

  alias ShEx.ShapeMap

  @iri ~I<http://example.com/foo>
  @bnode ~B<foo>
  @literal ~L"foo"
  @shape_label ~I<http://example.com/Shape>

  describe "new/1" do
    test "when given a map of node-shape identifier pairs" do
      assert ShapeMap.new(%{@iri => @shape_label}) ==
               %ShapeMap{type: :fixed, conformant: [%ShapeMap.Association{node: @iri, shape: @shape_label}]}
      assert ShapeMap.new(%{@bnode => @shape_label}) ==
               %ShapeMap{type: :fixed, conformant: [%ShapeMap.Association{node: @bnode, shape: @shape_label}]}
      assert ShapeMap.new(%{@literal => @shape_label}) ==
               %ShapeMap{type: :fixed, conformant: [%ShapeMap.Association{node: @literal, shape: @shape_label}]}

      assert ShapeMap.new(%{
               @iri => @shape_label,
               @bnode => @shape_label,
               @literal => @shape_label
             }) == %ShapeMap{type: :fixed, conformant: [
               %ShapeMap.Association{node: @bnode, shape: @shape_label},
               %ShapeMap.Association{node: @iri, shape: @shape_label},
               %ShapeMap.Association{node: @literal, shape: @shape_label},
             ]}
    end

    test "when given a map with triple patterns" do
      # TODO:
    end
  end

  describe "fixed?/1" do
    test "returns true when given a fixed ShapeMap" do
      assert ShapeMap.fixed?(%ShapeMap{type: :fixed}) == true
    end

    test "returns false when given a query ShapeMap" do
      assert ShapeMap.fixed?(%ShapeMap{type: :query}) == false
    end

    test "returns false when given a result ShapeMap" do
      assert ShapeMap.fixed?(%ShapeMap{type: :result}) == false
    end

    test "returns nil when given a ShapeMap with an unknown type" do
      assert ShapeMap.fixed?(%ShapeMap{type: :foo}) == nil
      assert ShapeMap.fixed?(%ShapeMap{type: nil}) == nil
    end
  end

  describe "query?/1" do
    test "returns true when given a fixed ShapeMap" do
      assert ShapeMap.query?(%ShapeMap{type: :fixed}) == true
    end

    test "returns true when given a query ShapeMap" do
      assert ShapeMap.query?(%ShapeMap{type: :query}) == true
    end

    test "returns true when given a result ShapeMap" do
      assert ShapeMap.query?(%ShapeMap{type: :result}) == false
    end

    test "returns nil when given a ShapeMap with an unknown type" do
      assert ShapeMap.query?(%ShapeMap{type: :foo}) == nil
      assert ShapeMap.query?(%ShapeMap{type: nil}) == nil
    end
  end

  describe "result?/1" do
    test "returns false when given a fixed ShapeMap" do
      assert ShapeMap.result?(%ShapeMap{type: :fixed}) == false
    end

    test "returns false when given a query ShapeMap" do
      assert ShapeMap.result?(%ShapeMap{type: :query}) == false
    end

    test "returns true when given a result ShapeMap" do
      assert ShapeMap.result?(%ShapeMap{type: :result}) == true
    end

    test "returns nil when given a ShapeMap with an unknown type" do
      assert ShapeMap.result?(%ShapeMap{type: :foo}) == nil
      assert ShapeMap.result?(%ShapeMap{type: nil}) == nil
    end
  end

  describe "to_fixed/1" do
    # TODO:
  end

end
