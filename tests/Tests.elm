module Tests exposing (..)

import Dict
import Expect
import Fuzz
import Json.Decode
import Json.Encode
import JsonToElm
import Test exposing (Test, describe, fuzz, test)


fuzzJsonValueObject : Fuzz.Fuzzer JsonToElm.JsonValue
fuzzJsonValueObject =
    Fuzz.map JsonToElm.JsonObject
        (Fuzz.map Dict.fromList
            (Fuzz.list
                (Fuzz.map2 Tuple.pair
                    Fuzz.string
                    fuzzBasicJsonValue
                )
            )
        )


fuzzJsonValueList : Fuzz.Fuzzer JsonToElm.JsonValue
fuzzJsonValueList =
    Fuzz.map JsonToElm.JsonList (Fuzz.list fuzzBasicJsonValue)


fuzzBasicJsonValue : Fuzz.Fuzzer JsonToElm.JsonValue
fuzzBasicJsonValue =
    Fuzz.oneOf
        [ Fuzz.map JsonToElm.JsonInt Fuzz.int
        , Fuzz.map JsonToElm.JsonFloat Fuzz.niceFloat
        , Fuzz.map JsonToElm.JsonBool Fuzz.bool
        , Fuzz.constant JsonToElm.JsonNull
        , Fuzz.map JsonToElm.JsonString Fuzz.string
        , Fuzz.lazy (\_ -> fuzzJsonValueList)
        , Fuzz.lazy (\_ -> fuzzJsonValueObject)
        ]


suite : Test
suite =
    describe "Tests for the `JsonToElm` module"
        [ fuzz Fuzz.int
            "When running `decode` on an encoded int, produces the correct `JsonToElm.Value`"
            (\int ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.int int)
                    |> Expect.equal (Ok (JsonToElm.JsonInt int))
            )
        , fuzz Fuzz.float
            "When running `decode` on an encoded float, produces the correct `JsonToElm.Value`"
            (\float ->
                if isInfinite float || isNaN float then
                    {- Pass this test is is infinite or is NaN. Should be fixed in the future! -}
                    Expect.pass

                else if float <= toFloat (ceiling float) then
                    {- If the above check succeeds, we're dealing with a whole number, so check to make
                       sure it's decoded, as expected, into a an `IntVal`, not a `FloatVal`
                    -}
                    Json.Decode.decodeValue JsonToElm.decode (Json.Encode.int (ceiling float))
                        |> Expect.equal (Ok (JsonToElm.JsonInt (ceiling float)))

                else
                    Json.Decode.decodeValue JsonToElm.decode (Json.Encode.float float)
                        |> Expect.equal (Ok (JsonToElm.JsonFloat float))
            )
        , fuzz Fuzz.string
            "When running `decode` on an encoded string, produces the correct `JsonToElm.Value`"
            (\string ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.string string)
                    |> Expect.equal (Ok (JsonToElm.JsonString string))
            )
        , fuzz Fuzz.bool
            "When running `decode` on an encoded bool, produces the correct `JsonToElm.Value`"
            (\bool ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.bool bool)
                    |> Expect.equal (Ok (JsonToElm.JsonBool bool))
            )
        , test "When running `decode` on an encoded null, produces the correct `JsonToElm.Value`"
            (\_ ->
                Json.Decode.decodeValue JsonToElm.decode Json.Encode.null
                    |> Expect.equal (Ok JsonToElm.JsonNull)
            )
        , fuzz (Fuzz.list Fuzz.string)
            "When running `decode` on an encoded list of strings, produces the correct `JsonToElm.Value`"
            (\stringList ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.list Json.Encode.string stringList)
                    |> Expect.equal (Ok (JsonToElm.JsonList (List.map JsonToElm.JsonString stringList)))
            )
        , fuzz (Fuzz.list Fuzz.int)
            "When running `decode` on an encoded list of ints, produces the correct `JsonToElm.Value`"
            (\intList ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.list Json.Encode.int intList)
                    |> Expect.equal (Ok (JsonToElm.JsonList (List.map JsonToElm.JsonInt intList)))
            )
        , fuzz
            (Fuzz.list
                {- This test doesn't work with generic `safeFloat` function when it hits the top and bottom of
                   the allowable range of numbers. So, instead, a range is provided.
                -}
                (Fuzz.floatRange -10000 10000)
            )
            "When running `decode` on an encoded list of floats, produces the correct `JsonToElm.Value`"
            (\floatList ->
                let
                    managedList =
                        List.map
                            (\float ->
                                if float <= toFloat (ceiling float) then
                                    {- If the above check succeeds, we're dealing with a whole number, so
                                       I make it a float.
                                    -}
                                    toFloat (ceiling float) + 0.1

                                else
                                    float
                            )
                            floatList
                in
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.list Json.Encode.float managedList)
                    |> Expect.equal (Ok (JsonToElm.JsonList (List.map JsonToElm.JsonFloat managedList)))
            )
        , fuzz (Fuzz.list Fuzz.bool)
            "When running `decode` on an encoded list of bools, produces the correct `JsonToElm.Value`"
            (\boolList ->
                Json.Decode.decodeValue JsonToElm.decode (Json.Encode.list Json.Encode.bool boolList)
                    |> Expect.equal (Ok (JsonToElm.JsonList (List.map JsonToElm.JsonBool boolList)))
            )
        , test "When given some JSON, can decode it into a `JsonToElm.Value`"
            (\_ ->
                let
                    example =
                        """{
  "browsers": {
    "firefox": {
      "name": "Firefox",
      "pref_url": "about:config",
      "releases": {
        "1": {
          "release_date": "2004-11-09",
          "status": "retired",
          "engine": "Gecko",
          "engine_version": "1.7"
        }
      }
    }
  }
}"""
                in
                Expect.all
                    [ Expect.ok
                    , Expect.equal
                        (Ok
                            (JsonToElm.JsonObject
                                (Dict.fromList
                                    [ ( "browsers"
                                      , JsonToElm.JsonObject
                                            (Dict.fromList
                                                [ ( "firefox"
                                                  , JsonToElm.JsonObject
                                                        (Dict.fromList
                                                            [ ( "name", JsonToElm.JsonString "Firefox" )
                                                            , ( "pref_url", JsonToElm.JsonString "about:config" )
                                                            , ( "releases"
                                                              , JsonToElm.JsonObject
                                                                    (Dict.fromList
                                                                        [ ( "1"
                                                                          , JsonToElm.JsonObject
                                                                                (Dict.fromList
                                                                                    [ ( "release_date", JsonToElm.JsonString "2004-11-09" )
                                                                                    , ( "status", JsonToElm.JsonString "retired" )
                                                                                    , ( "engine", JsonToElm.JsonString "Gecko" )
                                                                                    , ( "engine_version", JsonToElm.JsonString "1.7" )
                                                                                    ]
                                                                                )
                                                                          )
                                                                        ]
                                                                    )
                                                              )
                                                            ]
                                                        )
                                                  )
                                                ]
                                            )
                                      )
                                    ]
                                )
                            )
                        )
                    ]
                    (Json.Decode.decodeString JsonToElm.decode example)
            )
        ]
