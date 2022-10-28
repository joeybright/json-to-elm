module JsonToElm exposing
    ( JsonValue(..)
    , decode
    )

{-| Take any encoded JSON (as a `Json.Encode.JsonValue`) and decode it into an Elm value.

@docs JsonValue

@docs decode

-}

import Dict exposing (Dict)
import Json.Decode
import Json.Encode


{-| A custom type that represents possible JSON values as an Elm type.
-}
type JsonValue
    = JsonInt Int
    | JsonFloat Float
    | JsonString String
    | JsonBool Bool
    | JsonList (List JsonValue)
    | JsonObject (Dict String JsonValue)
    | JsonNull
    | JsonUnknown Json.Encode.Value


{-| A decoder for coverting a `Json.Encode.JsonValue` into a `JsonValue`.

If you run `decode` on the following JSON:

    {
        "name": "John",
        "age": 10,
        "money": 10.2,
        "isTired": "true",
        "objects": [ "wallet", "phone", "keys" ]
    }

You will get the following `JsonValue` result:

    JsonObject
        (Dict.fromList
            [ ( "name", JsonString "John" )
            , ( "age", JsonInt 10 )
            , ( "money", JsonFloat 10.2 )
            , ( "isTired", JsonBool True )
            , ( "object"
              , JsonList
                    [ JsonString "wallet"
                    , JsonString "phone"
                    , JsonString "keys"
                    ]
              )
            ]
        )

You can then manipulate the returned Elm type however you'd like in your program!

-}
decode : Json.Decode.Decoder JsonValue
decode =
    Json.Decode.oneOf
        [ {- The values below are basic values (int, bool, string, float) are easy to decode. Note that the
             order here is important! We want to check for `Int` before `Float` because 0 _should_ be
             decoded as a valid `Int`, but is also a valid `Float`!
          -}
          Json.Decode.map JsonInt Json.Decode.int
        , Json.Decode.map JsonFloat Json.Decode.float
        , Json.Decode.map JsonBool Json.Decode.bool
        , Json.Decode.map JsonString Json.Decode.string
        , Json.Decode.map JsonList (Json.Decode.list (Json.Decode.lazy (\_ -> decode)))
        , Json.Decode.map (Dict.fromList >> JsonObject) (Json.Decode.keyValuePairs (Json.Decode.lazy (\_ -> decode)))
        , Json.Decode.null JsonNull

        {- The above code _should_ capture all possible valid JSonWhen everything else is tried (and fails), the returned
           value is considered unknown and the value is captured as a `Json.Decode.JsonValue`.
        -}
        , Json.Decode.map JsonUnknown Json.Decode.value
        ]
