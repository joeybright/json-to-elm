# json-to-elm

Decodes JSON into a custom Elm type and provides helpers for generating encoders and decoders for that  with elm-codegen.

## When to Use

This package was designed and built to help with taking JSON of an unknown shape and generating code for encoding / decoding it with `elm-codegen`. I'm not sure if there are many good uses for this package beyond that use-case!

## Quick Start

To get started, run the `decode` function with some JSON. This can be JSON encoded in your Elm app or JSON from an external source, like flags or ports.

```elm
decodeToElm : Json.Decode.Value -> Result Json.Decode.Error JsonToElm.Value
decodeToElm json =
    Json.Decode.decodeValue JsonToElm.decode json
```

If the JSON passed to the function above had this shape:

```json
{
    "name": "Joshua",
    "friends": ["John", "Cindy", "Leslie"],
    "active": "true"
}
```

It would result in the following `JsonToElm.Value` being returned:

```elm
JsonToElm.Record
    (Dict.fromList 
        [ ( "name", JsonToElm.StringVal "Joshua" )
        , ( "friends"
          , JsonToElm.ListVal 
            [ JsonToElm.StringVal "John"
            , JsonToElm.StringVal "Cindy"
            , JsonToElm.StringVal "Leslie"
            ] 
          )
        , ( "active", JsonToElm.BoolVal True )
        ]
    )
```
