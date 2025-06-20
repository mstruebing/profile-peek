module API exposing (FaceitData, Response, Site, assetUrl, baseUrl, playerUrl, responseDecoder, responseEncoder, siteDecoder, siteEncoder, sitesDecoder)

import Json.Decode exposing (Decoder, field)
import Json.Encode
import Json.Encode.Extra


type alias Site =
    { title : String, url : String }


type alias Response =
    { steam_id : String
    , sites : List Site
    , faceitData : Maybe FaceitData
    }


type alias FaceitData =
    { nickname : String
    , avatar : String
    , country : String
    , elo : Int
    , level : Int
    }


baseUrl : String
baseUrl =
    "https://profile-peek.com"


apiUrl : String
apiUrl =
    baseUrl ++ "/api/v1"


playerUrl : String
playerUrl =
    apiUrl ++ "/player"


assetUrl : String
assetUrl =
    baseUrl ++ "/assets"


responseDecoder : Decoder Response
responseDecoder =
    Json.Decode.map3 Response
        (field "steam_id" Json.Decode.string)
        sitesDecoder
        faceitDecoder


sitesDecoder : Decoder (List Site)
sitesDecoder =
    field "sites" (Json.Decode.list siteDecoder)


siteDecoder : Decoder Site
siteDecoder =
    Json.Decode.map2 Site
        (field "title" Json.Decode.string)
        (field "url" Json.Decode.string)


responseEncoder : Response -> Json.Encode.Value
responseEncoder response =
    Json.Encode.object
        [ ( "steam_id", Json.Encode.string response.steam_id )
        , ( "sites", Json.Encode.list siteEncoder response.sites )
        , ( "faceit_data", Json.Encode.Extra.maybe faceitDataEncoder response.faceitData )
        ]


siteEncoder : Site -> Json.Encode.Value
siteEncoder site =
    Json.Encode.object
        [ ( "title", Json.Encode.string site.title )
        , ( "url", Json.Encode.string site.url )
        ]


faceitDecoder : Decoder (Maybe FaceitData)
faceitDecoder =
    field "faceit_data" (Json.Decode.maybe faceitDataDecoder)


faceitDataDecoder : Decoder FaceitData
faceitDataDecoder =
    Json.Decode.map5 FaceitData
        (field "nickname" Json.Decode.string)
        (field "avatar" Json.Decode.string)
        (field "country" Json.Decode.string)
        (field "elo" Json.Decode.int)
        (field "level" Json.Decode.int)


faceitDataEncoder : FaceitData -> Json.Encode.Value
faceitDataEncoder faceitData =
    Json.Encode.object
        [ ( "nickname", Json.Encode.string faceitData.nickname )
        , ( "avatar", Json.Encode.string faceitData.avatar )
        , ( "country", Json.Encode.string faceitData.country )
        , ( "elo", Json.Encode.int faceitData.elo )
        , ( "level", Json.Encode.int faceitData.level )
        ]
