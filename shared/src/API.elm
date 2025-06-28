module API exposing (FaceitData, Response, Site, assetUrl, baseUrl, playerUrl, responseDecoder, responseEncoder, siteDecoder, siteEncoder, sitesDecoder)

import Json.Decode exposing (Decoder, andThen, field, map, succeed)
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
    { account_created : Int
    , adr : Float
    , avatar : String
    , country : String
    , deaths : Int
    , double_kills : Int
    , elo : Int
    , headshots : Int
    , headshot_percentage : Float
    , kd_ratio : Float
    , kills : Int
    , kr_ratio : Float
    , level : Int
    , losses : Int
    , nickname : String
    , penta_kills : Int
    , quadro_kills : Int
    , triple_kills : Int
    , win_rate : Int
    , wins : Int
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
    succeed FaceitData
        |> decodeApply (field "account_created" Json.Decode.int)
        |> decodeApply (field "adr" Json.Decode.float)
        |> decodeApply (field "avatar" Json.Decode.string)
        |> decodeApply (field "country" Json.Decode.string)
        |> decodeApply (field "deaths" Json.Decode.int)
        |> decodeApply (field "double_kills" Json.Decode.int)
        |> decodeApply (field "elo" Json.Decode.int)
        |> decodeApply (field "headshots" Json.Decode.int)
        |> decodeApply (field "headshot_percentage" Json.Decode.float)
        |> decodeApply (field "kd_ratio" Json.Decode.float)
        |> decodeApply (field "kills" Json.Decode.int)
        |> decodeApply (field "kr_ratio" Json.Decode.float)
        |> decodeApply (field "level" Json.Decode.int)
        |> decodeApply (field "losses" Json.Decode.int)
        |> decodeApply (field "nickname" Json.Decode.string)
        |> decodeApply (field "penta_kills" Json.Decode.int)
        |> decodeApply (field "quadro_kills" Json.Decode.int)
        |> decodeApply (field "triple_kills" Json.Decode.int)
        |> decodeApply (field "win_rate" Json.Decode.int)
        |> decodeApply (field "wins" Json.Decode.int)


faceitDataEncoder : FaceitData -> Json.Encode.Value
faceitDataEncoder faceitData =
    Json.Encode.object
        [ ( "account_created", Json.Encode.int faceitData.account_created )
        , ( "adr", Json.Encode.float faceitData.adr )
        , ( "avatar", Json.Encode.string faceitData.avatar )
        , ( "country", Json.Encode.string faceitData.country )
        , ( "deaths", Json.Encode.int faceitData.deaths )
        , ( "double_kills", Json.Encode.int faceitData.double_kills )
        , ( "elo", Json.Encode.int faceitData.elo )
        , ( "headshots", Json.Encode.int faceitData.headshots )
        , ( "headshot_percentage", Json.Encode.float faceitData.headshot_percentage )
        , ( "kd_ratio", Json.Encode.float faceitData.kd_ratio )
        , ( "kills", Json.Encode.int faceitData.kills )
        , ( "kr_ratio", Json.Encode.float faceitData.kr_ratio )
        , ( "level", Json.Encode.int faceitData.level )
        , ( "losses", Json.Encode.int faceitData.losses )
        , ( "nickname", Json.Encode.string faceitData.nickname )
        , ( "penta_kills", Json.Encode.int faceitData.penta_kills )
        , ( "quadro_kills", Json.Encode.int faceitData.quadro_kills )
        , ( "triple_kills", Json.Encode.int faceitData.triple_kills )
        , ( "win_rate", Json.Encode.int faceitData.win_rate )
        , ( "wins", Json.Encode.int faceitData.wins )
        ]


decodeApply : Decoder a -> Decoder (a -> b) -> Decoder b
decodeApply value partial =
    andThen (\p -> map p value) partial
