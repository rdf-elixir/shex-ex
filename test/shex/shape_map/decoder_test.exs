defmodule ShEx.ShapeMap.DecoderTest do
  use ExUnit.Case
  doctest ShEx.ShapeMap.Decoder

  alias ShEx.ShapeMap

  import RDF.Sigils

  test "empty ShapeMap" do
    assert ShapeMap.Decoder.decode("") == {:ok, ShapeMap.new([])}
  end

  test "fixed ShapeMap of a node/shape pair" do
    assert ShapeMap.Decoder.decode("""
             # a simple node/shape pair
             <http://data.example/#n1> @ <http://data.example/#S2>
             """) ==
           {:ok, ShapeMap.new(%{~I<http://data.example/#n1> => ~I<http://data.example/#S2>})}
  end

  test "fixed ShapeMap of a literal/shape pair" do
    assert ShapeMap.Decoder.decode(~s["chat"@en-fr@<http://...S3>]) ==
             {:ok, ShapeMap.new(%{RDF.literal("chat", language: "en-fr") => ~I<http://...S3>})}
  end

  test "fixed ShapeMap of a node/start shape pair" do
    expected_shape_map = ShapeMap.new(%{~I<http://data.example/#n1> => :start})
    assert ShapeMap.Decoder.decode("<http://data.example/#n1> @START") ==
             {:ok, expected_shape_map}
    assert ShapeMap.Decoder.decode("<http://data.example/#n1> @ START") ==
             {:ok, expected_shape_map}
  end

  test "query ShapeMap with FOCUS on subject and 'a' keyword" do
    expected_shape_map =
      ShapeMap.new(%{{:focus, RDF.type, ~I<http://schema.example/Some/Type>} =>
        :start})
    assert {:ok, ^expected_shape_map} =
             ShapeMap.Decoder.decode("""
               # validate everything with type Some/Type as the START shape.
               {FOCUS a <http://schema.example/Some/Type>}@START
               """)
  end

  test "query ShapeMap with FOCUS on object and wildcard subject" do
    assert ShapeMap.Decoder.decode("""
             # Validate all objects of p3.
             {_ <http://...p3> FOCUS}@START
             """) ==
             {:ok, ShapeMap.new(%{{:_, ~I<http://...p3>, :focus} => :start})}
  end

  test "query ShapeMap with multiple associations" do
    assert ShapeMap.Decoder.decode("""
             # Validate a simple node/shape pair.
             <http://data.example/#n1> @ <http://data.example/#S2>,
             # Validate a literal as S3.
             "chat"@en-fr@<http://...S3>,
             # validate everything with type Some/Type as the START shape.
             {FOCUS a <http://schema.example/Some/Type>}@START,
             # Validate all objects of p3.
             {_ <http://...p3> FOCUS}@START
             """) ==
           {:ok, ShapeMap.new([
             {~I<http://data.example/#n1>, ~I<http://data.example/#S2>},
             {RDF.literal("chat", language: "en-fr"), ~I<http://...S3>},
             {{:focus, RDF.type, ~I<http://schema.example/Some/Type>}, :start},
             {{:_, ~I<http://...p3>, :focus}, :start},
           ])}
  end
end
